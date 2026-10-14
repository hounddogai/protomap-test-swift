import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning milestone is in its life cycle.
    enum CleaningMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a cleaning milestone and its current status.
    final class CleaningMilestone {
        var code: String
        var name: String
        var locale: String
        var windowDays: Int
        var allergy: String
        var currency: String
        var budget: Double
        var startsAt: Int
        var notes: String
        var dosageMg: Double
        var source: String
        var status: CleaningMilestoneStatus

        init(code: String, name: String, locale: String, windowDays: Int, allergy: String, currency: String, budget: Double, startsAt: Int, notes: String, dosageMg: Double, source: String, status: CleaningMilestoneStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.windowDays = windowDays
            self.allergy = allergy
            self.currency = currency
            self.budget = budget
            self.startsAt = startsAt
            self.notes = notes
            self.dosageMg = dosageMg
            self.source = source
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

        func canMoveTo(_ next: CleaningMilestoneStatus) -> Bool {
            switch status {
            case .new:
                return next == CleaningMilestoneStatus.running || next == CleaningMilestoneStatus.failed
            case .queued:
                return next == CleaningMilestoneStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CleaningMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(startsAt) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> CleaningMilestone {
            return CleaningMilestone(
                code: code,
                name: name,
                locale: locale,
                windowDays: windowDays,
                allergy: allergy,
                currency: currency,
                budget: budget,
                startsAt: startsAt,
                notes: notes,
                dosageMg: dosageMg,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a cleaning milestone in status new.
    static func newCleaningMilestone(_ code: String, name: String) -> CleaningMilestone {
        return CleaningMilestone(
            code: code,
            name: name,
            locale: "",
            windowDays: 0,
            allergy: "",
            currency: "",
            budget: 0.0,
            startsAt: 0,
            notes: "",
            dosageMg: 0.0,
            source: "",
            status: CleaningMilestoneStatus.new
        )
    }
}
