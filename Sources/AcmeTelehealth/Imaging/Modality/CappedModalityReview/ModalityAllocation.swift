import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality allocation is in its life cycle.
    enum ModalityAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a modality allocation and its current status.
    final class ModalityAllocation {
        var code: String
        var label: String
        var locale: String
        var tags: [String]
        var visible: Bool
        var endsAt: Int
        var category: String
        var batchSize: Int
        var encounterID: String
        var phone: String
        var budget: Double
        var status: ModalityAllocationStatus

        init(code: String, label: String, locale: String, tags: [String], visible: Bool, endsAt: Int, category: String, batchSize: Int, encounterID: String, phone: String, budget: Double, status: ModalityAllocationStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.tags = tags
            self.visible = visible
            self.endsAt = endsAt
            self.category = category
            self.batchSize = batchSize
            self.encounterID = encounterID
            self.phone = phone
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ModalityAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("modality allocation") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return ((budget + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityAllocation {
            return ModalityAllocation(
                code: code,
                label: label,
                locale: locale,
                tags: tags,
                visible: visible,
                endsAt: endsAt,
                category: category,
                batchSize: batchSize,
                encounterID: encounterID,
                phone: phone,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a modality allocation in status planned.
    static func newModalityAllocation(_ code: String, label: String) -> ModalityAllocation {
        return ModalityAllocation(
            code: code,
            label: label,
            locale: "",
            tags: [],
            visible: false,
            endsAt: 0,
            category: "",
            batchSize: 0,
            encounterID: "",
            phone: "",
            budget: 0.0,
            status: ModalityAllocationStatus.planned
        )
    }
}
