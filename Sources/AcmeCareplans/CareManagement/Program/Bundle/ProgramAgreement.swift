import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program agreement is in its life cycle.
    enum ProgramAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A program agreement. Its code is unique within a tenant.
    final class ProgramAgreement {
        var code: String
        var label: String
        var margin: Double
        var summary: String
        var ratio: Double
        var segment: String
        var source: String
        var status: ProgramAgreementStatus

        init(code: String, label: String, margin: Double, summary: String, ratio: Double, segment: String, source: String, status: ProgramAgreementStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.summary = summary
            self.ratio = ratio
            self.segment = segment
            self.source = source
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

        func canMoveTo(_ next: ProgramAgreementStatus) -> Bool {
            switch status {
            case .created:
                return next == ProgramAgreementStatus.retired
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

        func moveTo(_ next: ProgramAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return ((ratio + margin) * 100).rounded() / 100
        }

        func copyValue() -> ProgramAgreement {
            return ProgramAgreement(
                code: code,
                label: label,
                margin: margin,
                summary: summary,
                ratio: ratio,
                segment: segment,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a program agreement in status created.
    static func newProgramAgreement(_ code: String, label: String) -> ProgramAgreement {
        return ProgramAgreement(
            code: code,
            label: label,
            margin: 0.0,
            summary: "",
            ratio: 0.0,
            segment: "",
            source: "",
            status: ProgramAgreementStatus.created
        )
    }
}
