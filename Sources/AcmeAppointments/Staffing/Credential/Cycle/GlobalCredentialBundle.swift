import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global credential bundle is in its life cycle.
    enum GlobalCredentialBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a global credential bundle and its current status.
    final class GlobalCredentialBundle {
        var code: String
        var name: String
        var label: String
        var attributes: [String: String]
        var dosageMg: Double
        var facility: String
        var bed: String
        var status: GlobalCredentialBundleStatus

        init(code: String, name: String, label: String, attributes: [String: String], dosageMg: Double, facility: String, bed: String, status: GlobalCredentialBundleStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.attributes = attributes
            self.dosageMg = dosageMg
            self.facility = facility
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalCredentialBundleStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalCredentialBundleStatus.warming || next == GlobalCredentialBundleStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == GlobalCredentialBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCredentialBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global credential bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global credential bundle") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> GlobalCredentialBundle {
            return GlobalCredentialBundle(
                code: code,
                name: name,
                label: label,
                attributes: attributes,
                dosageMg: dosageMg,
                facility: facility,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a global credential bundle in status idle.
    static func newGlobalCredentialBundle(_ code: String, name: String) -> GlobalCredentialBundle {
        return GlobalCredentialBundle(
            code: code,
            name: name,
            label: "",
            attributes: [:],
            dosageMg: 0.0,
            facility: "",
            bed: "",
            status: GlobalCredentialBundleStatus.idle
        )
    }
}
