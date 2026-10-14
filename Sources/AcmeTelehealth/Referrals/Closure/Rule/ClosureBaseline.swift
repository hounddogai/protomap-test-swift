import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure baseline is in its life cycle.
    enum ClosureBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A closure baseline as the closure team keeps it.
    final class ClosureBaseline {
        var code: String
        var label: String
        var diagnosisCode: String
        var source: String
        var endsAt: Int
        var revision: Int
        var createdAt: Int
        var unit: String
        var expiresAt: Int
        var facility: String
        var status: ClosureBaselineStatus

        init(code: String, label: String, diagnosisCode: String, source: String, endsAt: Int, revision: Int, createdAt: Int, unit: String, expiresAt: Int, facility: String, status: ClosureBaselineStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.source = source
            self.endsAt = endsAt
            self.revision = revision
            self.createdAt = createdAt
            self.unit = unit
            self.expiresAt = expiresAt
            self.facility = facility
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

        func canMoveTo(_ next: ClosureBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == ClosureBaselineStatus.active
            case .pending:
                return next == ClosureBaselineStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ClosureBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("closure baseline") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(createdAt) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> ClosureBaseline {
            return ClosureBaseline(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                source: source,
                endsAt: endsAt,
                revision: revision,
                createdAt: createdAt,
                unit: unit,
                expiresAt: expiresAt,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a closure baseline in status draft.
    static func newClosureBaseline(_ code: String, label: String) -> ClosureBaseline {
        return ClosureBaseline(
            code: code,
            label: label,
            diagnosisCode: "",
            source: "",
            endsAt: 0,
            revision: 0,
            createdAt: 0,
            unit: "",
            expiresAt: 0,
            facility: "",
            status: ClosureBaselineStatus.draft
        )
    }
}
