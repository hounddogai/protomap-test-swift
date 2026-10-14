import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient bed board draft is in its life cycle.
    enum LenientBedBoardDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One lenient bed board draft, with what the planners need to act on it.
    final class LenientBedBoardDraft {
        var code: String
        var label: String
        var copay: Double
        var retries: Int
        var bed: String
        var locale: String
        var region: String
        var visitMinutes: Int
        var active: Bool
        var weight: Double
        var unit: String
        var status: LenientBedBoardDraftStatus

        init(code: String, label: String, copay: Double, retries: Int, bed: String, locale: String, region: String, visitMinutes: Int, active: Bool, weight: Double, unit: String, status: LenientBedBoardDraftStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.retries = retries
            self.bed = bed
            self.locale = locale
            self.region = region
            self.visitMinutes = visitMinutes
            self.active = active
            self.weight = weight
            self.unit = unit
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

        func canMoveTo(_ next: LenientBedBoardDraftStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LenientBedBoardDraftStatus.draining || next == LenientBedBoardDraftStatus.stopped
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

        func moveTo(_ next: LenientBedBoardDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient bed board draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(visitMinutes) - weight) * 100).rounded() / 100
        }

        func copyValue() -> LenientBedBoardDraft {
            return LenientBedBoardDraft(
                code: code,
                label: label,
                copay: copay,
                retries: retries,
                bed: bed,
                locale: locale,
                region: region,
                visitMinutes: visitMinutes,
                active: active,
                weight: weight,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient bed board draft in status idle.
    static func newLenientBedBoardDraft(_ code: String, label: String) -> LenientBedBoardDraft {
        return LenientBedBoardDraft(
            code: code,
            label: label,
            copay: 0.0,
            retries: 0,
            bed: "",
            locale: "",
            region: "",
            visitMinutes: 0,
            active: false,
            weight: 0.0,
            unit: "",
            status: LenientBedBoardDraftStatus.idle
        )
    }
}
