*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             Collections
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets
Library             OperatingSystem


*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    #Directory Cleanup
    Open the robot order website
    #Download the Excel file
    ${orders}=    Get orders
    #RETURN    ${orders}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the order
        ${orderid}    ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file    IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
#Directory Cleanup
#Empty Directory    ${OUTPUT_DIR}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv    dialect=excel
    RETURN    ${table}
    #Log    Found columns: ${table.columns}

Close the annoying modal
    Wait Until Element Contains    xpath=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]    OK
    Click Button    OK

Fill the form
    [Arguments]    ${table}
    Select From List by Value    xpath=//*[@id="head"]    ${table}[Head]
    Select Radio Button    body    ${table}[Body]
    Input Text    xpath=/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${table}[Legs]
    Input Text    xpath=//*[@id="address"]    ${table}[Address]

Preview the robot
    Click Button    xpath=//*[@id="preview"]
    Wait Until Element Is Visible    xpath=//*[@id="robot-preview-image"]

Submit the order
    #Mute Run On Failure    Page Should Contain Element
    Click Button    xpath=//*[@id="order"]
    Page Should Contain Element    xpath=//*[@id="receipt"]

Take a screenshot of the robot
    # Define local variables for the UI elements
    Wait Until Element Is Visible    xpath=//html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Wait Until Element Is Visible    xpath=//*[@id="robot-preview-image"]
    #get the order ID
    ${orderid}=    Get Text    xpath=//*[@id="receipt"]/p[1]
    # Create the File Name
    Set Local Variable    ${new_img_filename}    ${OUTPUT_DIR}${/}${orderid}.png
    Sleep    1sec
    Log To Console    Capturing Screenshot to ${new_img_filename}
    Capture Element Screenshot    xpath=//*[@id="robot-preview-image"]    ${new_img_filename}
    RETURN    ${orderid}    ${new_img_filename}

Go to order another robot
    Wait Until Element Is Visible    xpath=//*[@id="order-another"]
    Click Button    xpath=//*[@id="order-another"]

Create a Zip File of the Receipts
    Archive Folder With ZIP    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}pdf_archive.zip    recursive=True    include=*.pdf

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}

    Wait Until Element Is Visible    xpath=//*[@id="receipt"]
    Log To Console    Printing ${ORDER_NUMBER}
    ${order_receipt_html}=    Get Element Attribute    xpath=//*[@id="receipt"]    outerHTML

    Set Local Variable    ${new_pdf_filename}    ${OUTPUT_DIR}${/}${ORDER_NUMBER}.pdf

    Html To Pdf    content=${order_receipt_html}    output_path=${new_pdf_filename}
    RETURN    ${new_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}

    Log To Console    Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}

    Open PDF    ${PDF_FILE}

    @{myfiles}=    Create List    ${IMG_FILE}:x=0,y=0

    Add Files To PDF    ${myfiles}    ${PDF_FILE}    ${True}

#    Close PDF    ${PDF_FILE}
