import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot bundle is in its life cycle.
    enum SlotBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a slot bundle and its current status.
    final class SlotBundle {
        var code: String
        var label: String
        var patientRef: String
        var locale: String
        var windowDays: Int
        var allergy: String
        var ceiling: Double
        var checksum: String
        var status: SlotBundleStatus

        init(code: String, label: String, patientRef: String, locale: String, windowDays: Int, allergy: String, ceiling: Double, checksum: String, status: SlotBundleStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.locale = locale
            self.windowDays = windowDays
            self.allergy = allergy
            self.ceiling = ceiling
            self.checksum = checksum
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

        func canMoveTo(_ next: SlotBundleStatus) -> Bool {
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
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == SlotBundleStatus.done
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

        func moveTo(_ next: SlotBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedVolume() -> Double {
            return ((Double(windowDays) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> SlotBundle {
            return SlotBundle(
                code: code,
                label: label,
                patientRef: patientRef,
                locale: locale,
                windowDays: windowDays,
                allergy: allergy,
                ceiling: ceiling,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a slot bundle in status new.
    static func newSlotBundle(_ code: String, label: String) -> SlotBundle {
        return SlotBundle(
            code: code,
            label: label,
            patientRef: "",
            locale: "",
            windowDays: 0,
            allergy: "",
            ceiling: 0.0,
            checksum: "",
            status: SlotBundleStatus.new
        )
    }
}
