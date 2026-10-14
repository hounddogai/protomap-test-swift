import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist bundle is in its life cycle.
    enum WorklistBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A worklist bundle. Its code is unique within a tenant.
    final class WorklistBundle {
        var code: String
        var label: String
        var copay: Double
        var minimum: Double
        var description: String
        var refills: Int
        var acuity: Int
        var diagnosisCode: String
        var sequence: Int
        var channel: String
        var status: WorklistBundleStatus

        init(code: String, label: String, copay: Double, minimum: Double, description: String, refills: Int, acuity: Int, diagnosisCode: String, sequence: Int, channel: String, status: WorklistBundleStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.minimum = minimum
            self.description = description
            self.refills = refills
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.channel = channel
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

        func canMoveTo(_ next: WorklistBundleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WorklistBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return ((Double(sequence) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> WorklistBundle {
            return WorklistBundle(
                code: code,
                label: label,
                copay: copay,
                minimum: minimum,
                description: description,
                refills: refills,
                acuity: acuity,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a worklist bundle in status created.
    static func newWorklistBundle(_ code: String, label: String) -> WorklistBundle {
        return WorklistBundle(
            code: code,
            label: label,
            copay: 0.0,
            minimum: 0.0,
            description: "",
            refills: 0,
            acuity: 0,
            diagnosisCode: "",
            sequence: 0,
            channel: "",
            status: WorklistBundleStatus.created
        )
    }
}
