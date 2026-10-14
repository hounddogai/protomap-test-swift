import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness bundle is in its life cycle.
    enum WitnessBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A witness bundle. Its code is unique within a tenant.
    final class WitnessBundle {
        var code: String
        var label: String
        var revision: Int
        var minimum: Double
        var patientRef: String
        var status: WitnessBundleStatus

        init(code: String, label: String, revision: Int, minimum: Double, patientRef: String, status: WitnessBundleStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.minimum = minimum
            self.patientRef = patientRef
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

        func canMoveTo(_ next: WitnessBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == WitnessBundleStatus.ready || next == WitnessBundleStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == WitnessBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("witness bundle") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(revision) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> WitnessBundle {
            return WitnessBundle(
                code: code,
                label: label,
                revision: revision,
                minimum: minimum,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a witness bundle in status idle.
    static func newWitnessBundle(_ code: String, label: String) -> WitnessBundle {
        return WitnessBundle(
            code: code,
            label: label,
            revision: 0,
            minimum: 0.0,
            patientRef: "",
            status: WitnessBundleStatus.idle
        )
    }
}
