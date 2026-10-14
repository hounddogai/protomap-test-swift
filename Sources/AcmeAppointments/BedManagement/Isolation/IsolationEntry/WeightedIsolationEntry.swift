import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted isolation entry is in its life cycle.
    enum WeightedIsolationEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted isolation entry as the isolation team keeps it.
    final class WeightedIsolationEntry {
        var code: String
        var label: String
        var approved: Bool
        var ceiling: Double
        var refills: Int
        var name: String
        var floorValue: Double
        var attributes: [String: String]
        var active: Bool
        var limit: Int
        var status: WeightedIsolationEntryStatus

        init(code: String, label: String, approved: Bool, ceiling: Double, refills: Int, name: String, floorValue: Double, attributes: [String: String], active: Bool, limit: Int, status: WeightedIsolationEntryStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.ceiling = ceiling
            self.refills = refills
            self.name = name
            self.floorValue = floorValue
            self.attributes = attributes
            self.active = active
            self.limit = limit
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

        func canMoveTo(_ next: WeightedIsolationEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == WeightedIsolationEntryStatus.active || next == WeightedIsolationEntryStatus.suspended
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: WeightedIsolationEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted isolation entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func adjustedLoad() -> Double {
            return ((floorValue - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedIsolationEntry {
            return WeightedIsolationEntry(
                code: code,
                label: label,
                approved: approved,
                ceiling: ceiling,
                refills: refills,
                name: name,
                floorValue: floorValue,
                attributes: attributes,
                active: active,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted isolation entry in status draft.
    static func newWeightedIsolationEntry(_ code: String, label: String) -> WeightedIsolationEntry {
        return WeightedIsolationEntry(
            code: code,
            label: label,
            approved: false,
            ceiling: 0.0,
            refills: 0,
            name: "",
            floorValue: 0.0,
            attributes: [:],
            active: false,
            limit: 0,
            status: WeightedIsolationEntryStatus.draft
        )
    }
}
