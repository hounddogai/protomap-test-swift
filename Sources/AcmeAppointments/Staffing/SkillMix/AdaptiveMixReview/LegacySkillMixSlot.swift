import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy skill mix slot is in its life cycle.
    enum LegacySkillMixSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One legacy skill mix slot, with what the planners need to act on it.
    final class LegacySkillMixSlot {
        var code: String
        var label: String
        var expiresAt: Int
        var country: String
        var tags: [String]
        var quantity: Int
        var allergy: String
        var status: LegacySkillMixSlotStatus

        init(code: String, label: String, expiresAt: Int, country: String, tags: [String], quantity: Int, allergy: String, status: LegacySkillMixSlotStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.country = country
            self.tags = tags
            self.quantity = quantity
            self.allergy = allergy
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

        func canMoveTo(_ next: LegacySkillMixSlotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LegacySkillMixSlotStatus.done || next == LegacySkillMixSlotStatus.failed
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

        func moveTo(_ next: LegacySkillMixSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy skill mix slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("legacy skill mix slot") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((Double(expiresAt) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> LegacySkillMixSlot {
            return LegacySkillMixSlot(
                code: code,
                label: label,
                expiresAt: expiresAt,
                country: country,
                tags: tags,
                quantity: quantity,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a legacy skill mix slot in status new.
    static func newLegacySkillMixSlot(_ code: String, label: String) -> LegacySkillMixSlot {
        return LegacySkillMixSlot(
            code: code,
            label: label,
            expiresAt: 0,
            country: "",
            tags: [],
            quantity: 0,
            allergy: "",
            status: LegacySkillMixSlotStatus.new
        )
    }
}
