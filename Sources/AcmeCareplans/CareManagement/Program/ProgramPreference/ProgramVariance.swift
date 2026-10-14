import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program variance is in its life cycle.
    enum ProgramVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One program variance, with what the planners need to act on it.
    final class ProgramVariance {
        var code: String
        var label: String
        var region: String
        var discount: Double
        var createdAt: Int
        var source: String
        var country: String
        var timezone: String
        var margin: Double
        var notes: String
        var archived: Bool
        var status: ProgramVarianceStatus

        init(code: String, label: String, region: String, discount: Double, createdAt: Int, source: String, country: String, timezone: String, margin: Double, notes: String, archived: Bool, status: ProgramVarianceStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.discount = discount
            self.createdAt = createdAt
            self.source = source
            self.country = country
            self.timezone = timezone
            self.margin = margin
            self.notes = notes
            self.archived = archived
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

        func canMoveTo(_ next: ProgramVarianceStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProgramVarianceStatus.active
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: ProgramVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("program variance") \(code)"
        }

        func netLoad() -> Double {
            return (discount * margin * 100).rounded() / 100
        }

        func copyValue() -> ProgramVariance {
            return ProgramVariance(
                code: code,
                label: label,
                region: region,
                discount: discount,
                createdAt: createdAt,
                source: source,
                country: country,
                timezone: timezone,
                margin: margin,
                notes: notes,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a program variance in status draft.
    static func newProgramVariance(_ code: String, label: String) -> ProgramVariance {
        return ProgramVariance(
            code: code,
            label: label,
            region: "",
            discount: 0.0,
            createdAt: 0,
            source: "",
            country: "",
            timezone: "",
            margin: 0.0,
            notes: "",
            archived: false,
            status: ProgramVarianceStatus.draft
        )
    }
}
