import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default priority agreement is in its life cycle.
    enum DefaultPriorityAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default priority agreement as the priority team keeps it.
    final class DefaultPriorityAgreement {
        var code: String
        var label: String
        var region: String
        var batchSize: Int
        var ceiling: Double
        var country: String
        var encounterID: String
        var sequence: Int
        var active: Bool
        var margin: Double
        var status: DefaultPriorityAgreementStatus

        init(code: String, label: String, region: String, batchSize: Int, ceiling: Double, country: String, encounterID: String, sequence: Int, active: Bool, margin: Double, status: DefaultPriorityAgreementStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.batchSize = batchSize
            self.ceiling = ceiling
            self.country = country
            self.encounterID = encounterID
            self.sequence = sequence
            self.active = active
            self.margin = margin
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

        func canMoveTo(_ next: DefaultPriorityAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DefaultPriorityAgreementStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultPriorityAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default priority agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveTotal() -> Double {
            return (Double(sequence) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> DefaultPriorityAgreement {
            return DefaultPriorityAgreement(
                code: code,
                label: label,
                region: region,
                batchSize: batchSize,
                ceiling: ceiling,
                country: country,
                encounterID: encounterID,
                sequence: sequence,
                active: active,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default priority agreement in status proposed.
    static func newDefaultPriorityAgreement(_ code: String, label: String) -> DefaultPriorityAgreement {
        return DefaultPriorityAgreement(
            code: code,
            label: label,
            region: "",
            batchSize: 0,
            ceiling: 0.0,
            country: "",
            encounterID: "",
            sequence: 0,
            active: false,
            margin: 0.0,
            status: DefaultPriorityAgreementStatus.proposed
        )
    }
}
