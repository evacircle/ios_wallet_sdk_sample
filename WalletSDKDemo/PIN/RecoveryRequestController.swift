//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet

class RecoveryRequestController : InputPINUI {
    @IBOutlet weak var forgotButton: UIButton!
    @IBOutlet weak var handleLabel: UILabel!
    @IBOutlet weak var recoverCodeTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var pinCode: String?

    override func viewDidLoad() {
        recoverCodeTextField.addDoneCancelToolbar()
        recoverCodeTextField.delegate = self
    }
    
    @IBAction func onForgotPIN(_ sender: Any) {
        Auth.shared.forgotPinCode() { result in
            switch result {
            case .success(let result):
                print("forgotPinCode \(result)")
                self.handleLabel.text = "Handle number \(result.handleNum)"
                self.forgotButton.isUserInteractionEnabled = false
                break
            case .failure(let error):
                print("forgotPinCode \(error)")
                break
            }
        }
    }
    
    @IBAction func onNext(_ sender: Any) {
        guard let recoveryCode = recoverCodeTextField.text else {
            return
        }
        Auth.shared.verifyRecoveryCode(recoveryCode: recoveryCode) { result in
            switch result {
            case .success(let result):
                print("verifyRecoveryCode \(result)")
                self.performSegue(withIdentifier: "idInputPINCode", sender: self);
                self.nextButton.isUserInteractionEnabled = false
                break
            case .failure(let error):
                print("verifyRecoveryCode \(error)")
                DispatchQueue.main.async {
                    let failAlert = UIAlertController(title: "Invalid recovery code", message: error.name, preferredStyle: .alert)
                    failAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(failAlert, animated: true)
                }
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if var ui = segue.destination as? PinCodeInputUI {
            ui.delegate = self
        }
        if var ui = segue.destination as? BackupChallengeInputUI {
            ui.delegate = self
        }
    }
}

let RECOVERYCODE_LENGTH = 8
extension RecoveryRequestController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0
        if (range.length + range.location > currentCharacterCount){
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length
        if newLength >= RECOVERYCODE_LENGTH {
            DispatchQueue.main.async {
                self.recoverCodeTextField.resignFirstResponder()
                self.forgotButton.isEnabled = true
            }
        }
        return newLength <= RECOVERYCODE_LENGTH
    }
}

extension RecoveryRequestController : PinCodeDelegate {
    func onPin(code: String) {
        pinCode = code
        self.performSegue(withIdentifier: "idInputBackupChallenge", sender: self);
    }
}

extension RecoveryRequestController : BackupChallengeDelegate {
    func onChallenges(_ challenges: [BackupChallenge]) {
        guard let pc = pinCode, let recoveryCode = recoverCodeTextField.text, challenges.count == 3 else {
            NavigationHelper.back(from: self)
            return
        }
        
        Auth.shared.recoverPinCode(pinCode: pc, recoveryCode: recoveryCode) { result in
            switch result {
            case .success(_):
                print("recovery pin code result")
                self.onSetPINSuccessed(backNum: 2)
                break
            case .failure(let error):
                print("recovery pin code failed \(error)")
                self.onSetPINFailed(error: error)
                break
            }
        }
    }
}
