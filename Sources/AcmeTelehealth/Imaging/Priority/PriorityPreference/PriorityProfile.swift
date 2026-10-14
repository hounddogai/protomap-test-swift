import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority profile is in its life cycle.
    enum PriorityProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A priority profile as the priority team keeps it.
    final class PriorityProfile {
        var code: String
        var title: String
        var sequence: Int
        var unit: String
        var budget: Double
        var locale: String
        var ownerID: String
        var archived: Bool
        var country: String
        var approved: Bool
        var status: PriorityProfileStatus

        init(code: String, title: String, sequence: Int, unit: String, budget: Double, locale: String, ownerID: String, archived: Bool, country: String, approved: Bool, status: PriorityProfileStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.unit = unit
            self.budget = budget
            self.locale = locale
            self.ownerID = ownerID
            self.archived = archived
            self.country = country
            self.approved = approved
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

        func canMoveTo(_ next: PriorityProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == PriorityProfileStatus.running
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PriorityProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return ((budget - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityProfile {
            return PriorityProfile(
                code: code,
                title: title,
                sequence: sequence,
                unit: unit,
                budget: budget,
                locale: locale,
                ownerID: ownerID,
                archived: archived,
                country: country,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a priority profile in status new.
    static func newPriorityProfile(_ code: String, title: String) -> PriorityProfile {
        return PriorityProfile(
            code: code,
            title: title,
            sequence: 0,
            unit: "",
            budget: 0.0,
            locale: "",
            ownerID: "",
            archived: false,
            country: "",
            approved: false,
            status: PriorityProfileStatus.new
        )
    }
}
