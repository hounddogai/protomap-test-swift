import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory plan is in its life cycle.
    enum InventoryPlanStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A inventory plan. Its code is unique within a tenant.
    final class InventoryPlan {
        var code: String
        var title: String
        var ceiling: Double
        var segment: String
        var windowDays: Int
        var ratio: Double
        var attributes: [String: String]
        var name: String
        var diagnosisCode: String
        var summary: String
        var updatedAt: Int
        var status: InventoryPlanStatus

        init(code: String, title: String, ceiling: Double, segment: String, windowDays: Int, ratio: Double, attributes: [String: String], name: String, diagnosisCode: String, summary: String, updatedAt: Int, status: InventoryPlanStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.segment = segment
            self.windowDays = windowDays
            self.ratio = ratio
            self.attributes = attributes
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: InventoryPlanStatus) -> Bool {
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
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == InventoryPlanStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netLoad() -> Double {
            return ((ratio + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryPlan {
            return InventoryPlan(
                code: code,
                title: title,
                ceiling: ceiling,
                segment: segment,
                windowDays: windowDays,
                ratio: ratio,
                attributes: attributes,
                name: name,
                diagnosisCode: diagnosisCode,
                summary: summary,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a inventory plan in status planned.
    static func newInventoryPlan(_ code: String, title: String) -> InventoryPlan {
        return InventoryPlan(
            code: code,
            title: title,
            ceiling: 0.0,
            segment: "",
            windowDays: 0,
            ratio: 0.0,
            attributes: [:],
            name: "",
            diagnosisCode: "",
            summary: "",
            updatedAt: 0,
            status: InventoryPlanStatus.planned
        )
    }
}
