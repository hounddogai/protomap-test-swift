import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient inventory group is in its life cycle.
    enum LenientInventoryGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One lenient inventory group, with what the planners need to act on it.
    final class LenientInventoryGroup {
        var code: String
        var title: String
        var refills: Int
        var segment: String
        var externalRef: String
        var pinned: Bool
        var description: String
        var allergy: String
        var summary: String
        var specialty: String
        var source: String
        var status: LenientInventoryGroupStatus

        init(code: String, title: String, refills: Int, segment: String, externalRef: String, pinned: Bool, description: String, allergy: String, summary: String, specialty: String, source: String, status: LenientInventoryGroupStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.segment = segment
            self.externalRef = externalRef
            self.pinned = pinned
            self.description = description
            self.allergy = allergy
            self.summary = summary
            self.specialty = specialty
            self.source = source
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

        func canMoveTo(_ next: LenientInventoryGroupStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientInventoryGroupStatus.queued || next == LenientInventoryGroupStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LenientInventoryGroupStatus.done || next == LenientInventoryGroupStatus.failed
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

        func moveTo(_ next: LenientInventoryGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient inventory group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> LenientInventoryGroup {
            return LenientInventoryGroup(
                code: code,
                title: title,
                refills: refills,
                segment: segment,
                externalRef: externalRef,
                pinned: pinned,
                description: description,
                allergy: allergy,
                summary: summary,
                specialty: specialty,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient inventory group in status new.
    static func newLenientInventoryGroup(_ code: String, title: String) -> LenientInventoryGroup {
        return LenientInventoryGroup(
            code: code,
            title: title,
            refills: 0,
            segment: "",
            externalRef: "",
            pinned: false,
            description: "",
            allergy: "",
            summary: "",
            specialty: "",
            source: "",
            status: LenientInventoryGroupStatus.new
        )
    }
}
