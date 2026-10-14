import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score batch is in its life cycle.
    enum RiskScoreBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A risk score batch as the risk score team keeps it.
    final class RiskScoreBatch {
        var code: String
        var title: String
        var floorValue: Double
        var ceiling: Double
        var visible: Bool
        var refills: Int
        var discount: Double
        var attributes: [String: String]
        var active: Bool
        var country: String
        var allergy: String
        var status: RiskScoreBatchStatus

        init(code: String, title: String, floorValue: Double, ceiling: Double, visible: Bool, refills: Int, discount: Double, attributes: [String: String], active: Bool, country: String, allergy: String, status: RiskScoreBatchStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.ceiling = ceiling
            self.visible = visible
            self.refills = refills
            self.discount = discount
            self.attributes = attributes
            self.active = active
            self.country = country
            self.allergy = allergy
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

        func canMoveTo(_ next: RiskScoreBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == RiskScoreBatchStatus.scheduled || next == RiskScoreBatchStatus.cancelled
            case .scheduled:
                return next == RiskScoreBatchStatus.completed || next == RiskScoreBatchStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RiskScoreBatchStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
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

        func effectiveVolume() -> Double {
            return ((Double(refills) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreBatch {
            return RiskScoreBatch(
                code: code,
                title: title,
                floorValue: floorValue,
                ceiling: ceiling,
                visible: visible,
                refills: refills,
                discount: discount,
                attributes: attributes,
                active: active,
                country: country,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a risk score batch in status planned.
    static func newRiskScoreBatch(_ code: String, title: String) -> RiskScoreBatch {
        return RiskScoreBatch(
            code: code,
            title: title,
            floorValue: 0.0,
            ceiling: 0.0,
            visible: false,
            refills: 0,
            discount: 0.0,
            attributes: [:],
            active: false,
            country: "",
            allergy: "",
            status: RiskScoreBatchStatus.planned
        )
    }
}
