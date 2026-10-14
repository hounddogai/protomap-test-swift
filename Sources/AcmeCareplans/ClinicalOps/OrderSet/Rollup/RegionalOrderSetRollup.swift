import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional order set rollup is in its life cycle.
    enum RegionalOrderSetRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional order set rollup. Its code is unique within a tenant.
    final class RegionalOrderSetRollup {
        var code: String
        var name: String
        var visible: Bool
        var label: String
        var revision: Int
        var status: RegionalOrderSetRollupStatus

        init(code: String, name: String, visible: Bool, label: String, revision: Int, status: RegionalOrderSetRollupStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.label = label
            self.revision = revision
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

        func canMoveTo(_ next: RegionalOrderSetRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalOrderSetRollupStatus.queued
            case .queued:
                return next == RegionalOrderSetRollupStatus.done || next == RegionalOrderSetRollupStatus.failed
            case .running:
                return next == RegionalOrderSetRollupStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RegionalOrderSetRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional order set rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("regional order set rollup") \(code)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> RegionalOrderSetRollup {
            return RegionalOrderSetRollup(
                code: code,
                name: name,
                visible: visible,
                label: label,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional order set rollup in status new.
    static func newRegionalOrderSetRollup(_ code: String, name: String) -> RegionalOrderSetRollup {
        return RegionalOrderSetRollup(
            code: code,
            name: name,
            visible: false,
            label: "",
            revision: 0,
            status: RegionalOrderSetRollupStatus.new
        )
    }
}
