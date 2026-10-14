import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default interaction agreement is in its life cycle.
    enum DefaultInteractionAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A default interaction agreement as the interaction team keeps it.
    final class DefaultInteractionAgreement {
        var code: String
        var title: String
        var graceDays: Int
        var sequence: Int
        var version: Int
        var weight: Double
        var name: String
        var bed: String
        var windowDays: Int
        var status: DefaultInteractionAgreementStatus

        init(code: String, title: String, graceDays: Int, sequence: Int, version: Int, weight: Double, name: String, bed: String, windowDays: Int, status: DefaultInteractionAgreementStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.sequence = sequence
            self.version = version
            self.weight = weight
            self.name = name
            self.bed = bed
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultInteractionAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == DefaultInteractionAgreementStatus.pending
            case .pending:
                return next == DefaultInteractionAgreementStatus.active || next == DefaultInteractionAgreementStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == DefaultInteractionAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultInteractionAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default interaction agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("default interaction agreement") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(windowDays) - weight) * 100).rounded() / 100
        }

        func copyValue() -> DefaultInteractionAgreement {
            return DefaultInteractionAgreement(
                code: code,
                title: title,
                graceDays: graceDays,
                sequence: sequence,
                version: version,
                weight: weight,
                name: name,
                bed: bed,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default interaction agreement in status draft.
    static func newDefaultInteractionAgreement(_ code: String, title: String) -> DefaultInteractionAgreement {
        return DefaultInteractionAgreement(
            code: code,
            title: title,
            graceDays: 0,
            sequence: 0,
            version: 0,
            weight: 0.0,
            name: "",
            bed: "",
            windowDays: 0,
            status: DefaultInteractionAgreementStatus.draft
        )
    }
}
