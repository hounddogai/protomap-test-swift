import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default risk score threshold is in its life cycle.
    enum DefaultRiskScoreThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default risk score threshold and its current status.
    final class DefaultRiskScoreThreshold {
        var code: String
        var title: String
        var graceDays: Int
        var discount: Double
        var approved: Bool
        var updatedAt: Int
        var ceiling: Double
        var checksum: String
        var currency: String
        var procedureCode: String
        var sequence: Int
        var status: DefaultRiskScoreThresholdStatus

        init(code: String, title: String, graceDays: Int, discount: Double, approved: Bool, updatedAt: Int, ceiling: Double, checksum: String, currency: String, procedureCode: String, sequence: Int, status: DefaultRiskScoreThresholdStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.discount = discount
            self.approved = approved
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.checksum = checksum
            self.currency = currency
            self.procedureCode = procedureCode
            self.sequence = sequence
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

        func canMoveTo(_ next: DefaultRiskScoreThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DefaultRiskScoreThresholdStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRiskScoreThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default risk score threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedLoad() -> Double {
            return (Double(graceDays) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> DefaultRiskScoreThreshold {
            return DefaultRiskScoreThreshold(
                code: code,
                title: title,
                graceDays: graceDays,
                discount: discount,
                approved: approved,
                updatedAt: updatedAt,
                ceiling: ceiling,
                checksum: checksum,
                currency: currency,
                procedureCode: procedureCode,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default risk score threshold in status proposed.
    static func newDefaultRiskScoreThreshold(_ code: String, title: String) -> DefaultRiskScoreThreshold {
        return DefaultRiskScoreThreshold(
            code: code,
            title: title,
            graceDays: 0,
            discount: 0.0,
            approved: false,
            updatedAt: 0,
            ceiling: 0.0,
            checksum: "",
            currency: "",
            procedureCode: "",
            sequence: 0,
            status: DefaultRiskScoreThresholdStatus.proposed
        )
    }
}
