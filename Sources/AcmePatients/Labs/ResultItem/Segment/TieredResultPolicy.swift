import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered result policy is in its life cycle.
    enum TieredResultPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered result policy. Its code is unique within a tenant.
    final class TieredResultPolicy {
        var code: String
        var title: String
        var source: String
        var name: String
        var visible: Bool
        var specialty: String
        var revision: Int
        var label: String
        var procedureCode: String
        var ceiling: Double
        var status: TieredResultPolicyStatus

        init(code: String, title: String, source: String, name: String, visible: Bool, specialty: String, revision: Int, label: String, procedureCode: String, ceiling: Double, status: TieredResultPolicyStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.name = name
            self.visible = visible
            self.specialty = specialty
            self.revision = revision
            self.label = label
            self.procedureCode = procedureCode
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredResultPolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TieredResultPolicyStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredResultPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered result policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func weightedVolume() -> Double {
            return ((Double(revision) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> TieredResultPolicy {
            return TieredResultPolicy(
                code: code,
                title: title,
                source: source,
                name: name,
                visible: visible,
                specialty: specialty,
                revision: revision,
                label: label,
                procedureCode: procedureCode,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered result policy in status new.
    static func newTieredResultPolicy(_ code: String, title: String) -> TieredResultPolicy {
        return TieredResultPolicy(
            code: code,
            title: title,
            source: "",
            name: "",
            visible: false,
            specialty: "",
            revision: 0,
            label: "",
            procedureCode: "",
            ceiling: 0.0,
            status: TieredResultPolicyStatus.new
        )
    }
}
