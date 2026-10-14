import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study claim is in its life cycle.
    enum StudyClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a study claim and its current status.
    final class StudyClaim {
        var code: String
        var label: String
        var quantity: Int
        var acuity: Int
        var floorValue: Double
        var category: String
        var batchSize: Int
        var payer: String
        var status: StudyClaimStatus

        init(code: String, label: String, quantity: Int, acuity: Int, floorValue: Double, category: String, batchSize: Int, payer: String, status: StudyClaimStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.acuity = acuity
            self.floorValue = floorValue
            self.category = category
            self.batchSize = batchSize
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StudyClaimStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StudyClaimStatus.withdrawn
            case .rejected:
                return next == StudyClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netVolume() -> Double {
            return (Double(batchSize) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> StudyClaim {
            return StudyClaim(
                code: code,
                label: label,
                quantity: quantity,
                acuity: acuity,
                floorValue: floorValue,
                category: category,
                batchSize: batchSize,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a study claim in status proposed.
    static func newStudyClaim(_ code: String, label: String) -> StudyClaim {
        return StudyClaim(
            code: code,
            label: label,
            quantity: 0,
            acuity: 0,
            floorValue: 0.0,
            category: "",
            batchSize: 0,
            payer: "",
            status: StudyClaimStatus.proposed
        )
    }
}
