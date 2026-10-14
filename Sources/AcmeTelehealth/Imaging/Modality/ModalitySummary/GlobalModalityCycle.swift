import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global modality cycle is in its life cycle.
    enum GlobalModalityCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global modality cycle. Its code is unique within a tenant.
    final class GlobalModalityCycle {
        var code: String
        var label: String
        var discount: Double
        var revision: Int
        var archived: Bool
        var version: Int
        var status: GlobalModalityCycleStatus

        init(code: String, label: String, discount: Double, revision: Int, archived: Bool, version: Int, status: GlobalModalityCycleStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.revision = revision
            self.archived = archived
            self.version = version
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

        func canMoveTo(_ next: GlobalModalityCycleStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalModalityCycleStatus.queued || next == GlobalModalityCycleStatus.running
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == GlobalModalityCycleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalModalityCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global modality cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return ((Double(version) + discount) * 100).rounded() / 100
        }

        func copyValue() -> GlobalModalityCycle {
            return GlobalModalityCycle(
                code: code,
                label: label,
                discount: discount,
                revision: revision,
                archived: archived,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global modality cycle in status new.
    static func newGlobalModalityCycle(_ code: String, label: String) -> GlobalModalityCycle {
        return GlobalModalityCycle(
            code: code,
            label: label,
            discount: 0.0,
            revision: 0,
            archived: false,
            version: 0,
            status: GlobalModalityCycleStatus.new
        )
    }
}
