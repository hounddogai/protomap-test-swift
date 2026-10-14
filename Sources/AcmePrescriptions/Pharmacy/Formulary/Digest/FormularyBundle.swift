import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary bundle is in its life cycle.
    enum FormularyBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a formulary bundle and its current status.
    final class FormularyBundle {
        var code: String
        var name: String
        var threshold: Double
        var version: Int
        var externalRef: String
        var attempts: Int
        var copay: Double
        var revision: Int
        var allergy: String
        var graceDays: Int
        var status: FormularyBundleStatus

        init(code: String, name: String, threshold: Double, version: Int, externalRef: String, attempts: Int, copay: Double, revision: Int, allergy: String, graceDays: Int, status: FormularyBundleStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.version = version
            self.externalRef = externalRef
            self.attempts = attempts
            self.copay = copay
            self.revision = revision
            self.allergy = allergy
            self.graceDays = graceDays
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

        func canMoveTo(_ next: FormularyBundleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
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

        func moveTo(_ next: FormularyBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("formulary bundle") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(revision) * threshold * 100).rounded() / 100
        }

        func copyValue() -> FormularyBundle {
            return FormularyBundle(
                code: code,
                name: name,
                threshold: threshold,
                version: version,
                externalRef: externalRef,
                attempts: attempts,
                copay: copay,
                revision: revision,
                allergy: allergy,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a formulary bundle in status created.
    static func newFormularyBundle(_ code: String, name: String) -> FormularyBundle {
        return FormularyBundle(
            code: code,
            name: name,
            threshold: 0.0,
            version: 0,
            externalRef: "",
            attempts: 0,
            copay: 0.0,
            revision: 0,
            allergy: "",
            graceDays: 0,
            status: FormularyBundleStatus.created
        )
    }
}
