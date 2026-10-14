import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board threshold is in its life cycle.
    enum BedBoardThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A bed board threshold. Its code is unique within a tenant.
    final class BedBoardThreshold {
        var code: String
        var title: String
        var startsAt: Int
        var budget: Double
        var summary: String
        var facility: String
        var createdAt: Int
        var allergy: String
        var tags: [String]
        var copay: Double
        var label: String
        var status: BedBoardThresholdStatus

        init(code: String, title: String, startsAt: Int, budget: Double, summary: String, facility: String, createdAt: Int, allergy: String, tags: [String], copay: Double, label: String, status: BedBoardThresholdStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.budget = budget
            self.summary = summary
            self.facility = facility
            self.createdAt = createdAt
            self.allergy = allergy
            self.tags = tags
            self.copay = copay
            self.label = label
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

        func canMoveTo(_ next: BedBoardThresholdStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BedBoardThresholdStatus.ready || next == BedBoardThresholdStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BedBoardThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return ((copay - budget) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardThreshold {
            return BedBoardThreshold(
                code: code,
                title: title,
                startsAt: startsAt,
                budget: budget,
                summary: summary,
                facility: facility,
                createdAt: createdAt,
                allergy: allergy,
                tags: tags,
                copay: copay,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a bed board threshold in status idle.
    static func newBedBoardThreshold(_ code: String, title: String) -> BedBoardThreshold {
        return BedBoardThreshold(
            code: code,
            title: title,
            startsAt: 0,
            budget: 0.0,
            summary: "",
            facility: "",
            createdAt: 0,
            allergy: "",
            tags: [],
            copay: 0.0,
            label: "",
            status: BedBoardThresholdStatus.idle
        )
    }
}
