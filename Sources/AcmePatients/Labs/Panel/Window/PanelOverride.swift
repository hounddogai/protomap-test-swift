import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel override is in its life cycle.
    enum PanelOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One panel override, with what the planners need to act on it.
    final class PanelOverride {
        var code: String
        var title: String
        var attributes: [String: String]
        var currency: String
        var bed: String
        var phone: String
        var batchSize: Int
        var acuity: Int
        var status: PanelOverrideStatus

        init(code: String, title: String, attributes: [String: String], currency: String, bed: String, phone: String, batchSize: Int, acuity: Int, status: PanelOverrideStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.currency = currency
            self.bed = bed
            self.phone = phone
            self.batchSize = batchSize
            self.acuity = acuity
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

        func canMoveTo(_ next: PanelOverrideStatus) -> Bool {
            switch status {
            case .planned:
                return next == PanelOverrideStatus.inProgress || next == PanelOverrideStatus.completed
            case .scheduled:
                return next == PanelOverrideStatus.inProgress || next == PanelOverrideStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PanelOverrideStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func adjustedVolume() -> Double {
            return (Double(acuity) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> PanelOverride {
            return PanelOverride(
                code: code,
                title: title,
                attributes: attributes,
                currency: currency,
                bed: bed,
                phone: phone,
                batchSize: batchSize,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel override in status planned.
    static func newPanelOverride(_ code: String, title: String) -> PanelOverride {
        return PanelOverride(
            code: code,
            title: title,
            attributes: [:],
            currency: "",
            bed: "",
            phone: "",
            batchSize: 0,
            acuity: 0,
            status: PanelOverrideStatus.planned
        )
    }
}
