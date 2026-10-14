import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness window is in its life cycle.
    enum WitnessWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A witness window. Its code is unique within a tenant.
    final class WitnessWindow {
        var code: String
        var label: String
        var clinicianID: String
        var region: String
        var retries: Int
        var checksum: String
        var threshold: Double
        var score: Double
        var quantity: Int
        var budget: Double
        var status: WitnessWindowStatus

        init(code: String, label: String, clinicianID: String, region: String, retries: Int, checksum: String, threshold: Double, score: Double, quantity: Int, budget: Double, status: WitnessWindowStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.region = region
            self.retries = retries
            self.checksum = checksum
            self.threshold = threshold
            self.score = score
            self.quantity = quantity
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == WitnessWindowStatus.published || next == WitnessWindowStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("witness window") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(quantity) + score) * 100).rounded() / 100
        }

        func copyValue() -> WitnessWindow {
            return WitnessWindow(
                code: code,
                label: label,
                clinicianID: clinicianID,
                region: region,
                retries: retries,
                checksum: checksum,
                threshold: threshold,
                score: score,
                quantity: quantity,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a witness window in status created.
    static func newWitnessWindow(_ code: String, label: String) -> WitnessWindow {
        return WitnessWindow(
            code: code,
            label: label,
            clinicianID: "",
            region: "",
            retries: 0,
            checksum: "",
            threshold: 0.0,
            score: 0.0,
            quantity: 0,
            budget: 0.0,
            status: WitnessWindowStatus.created
        )
    }
}
