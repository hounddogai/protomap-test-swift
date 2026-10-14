import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled substitution group is in its life cycle.
    enum ScheduledSubstitutionGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled substitution group. Its code is unique within a tenant.
    final class ScheduledSubstitutionGroup {
        var code: String
        var title: String
        var ward: String
        var score: Double
        var durationMinutes: Int
        var createdAt: Int
        var visible: Bool
        var summary: String
        var currency: String
        var sequence: Int
        var status: ScheduledSubstitutionGroupStatus

        init(code: String, title: String, ward: String, score: Double, durationMinutes: Int, createdAt: Int, visible: Bool, summary: String, currency: String, sequence: Int, status: ScheduledSubstitutionGroupStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.score = score
            self.durationMinutes = durationMinutes
            self.createdAt = createdAt
            self.visible = visible
            self.summary = summary
            self.currency = currency
            self.sequence = sequence
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

        func canMoveTo(_ next: ScheduledSubstitutionGroupStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledSubstitutionGroupStatus.validated || next == ScheduledSubstitutionGroupStatus.retired
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

        func moveTo(_ next: ScheduledSubstitutionGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled substitution group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((Double(durationMinutes) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledSubstitutionGroup {
            return ScheduledSubstitutionGroup(
                code: code,
                title: title,
                ward: ward,
                score: score,
                durationMinutes: durationMinutes,
                createdAt: createdAt,
                visible: visible,
                summary: summary,
                currency: currency,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled substitution group in status created.
    static func newScheduledSubstitutionGroup(_ code: String, title: String) -> ScheduledSubstitutionGroup {
        return ScheduledSubstitutionGroup(
            code: code,
            title: title,
            ward: "",
            score: 0.0,
            durationMinutes: 0,
            createdAt: 0,
            visible: false,
            summary: "",
            currency: "",
            sequence: 0,
            status: ScheduledSubstitutionGroupStatus.created
        )
    }
}
