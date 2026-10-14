import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient formulary draft is in its life cycle.
    enum LenientFormularyDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a lenient formulary draft and its current status.
    final class LenientFormularyDraft {
        var code: String
        var name: String
        var tags: [String]
        var retries: Int
        var timezone: String
        var rate: Double
        var status: LenientFormularyDraftStatus

        init(code: String, name: String, tags: [String], retries: Int, timezone: String, rate: Double, status: LenientFormularyDraftStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.retries = retries
            self.timezone = timezone
            self.rate = rate
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

        func canMoveTo(_ next: LenientFormularyDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientFormularyDraftStatus.running || next == LenientFormularyDraftStatus.failed
            case .queued:
                return next == LenientFormularyDraftStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LenientFormularyDraftStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientFormularyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient formulary draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return ((Double(retries) + rate) * 100).rounded() / 100
        }

        func copyValue() -> LenientFormularyDraft {
            return LenientFormularyDraft(
                code: code,
                name: name,
                tags: tags,
                retries: retries,
                timezone: timezone,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient formulary draft in status new.
    static func newLenientFormularyDraft(_ code: String, name: String) -> LenientFormularyDraft {
        return LenientFormularyDraft(
            code: code,
            name: name,
            tags: [],
            retries: 0,
            timezone: "",
            rate: 0.0,
            status: LenientFormularyDraftStatus.new
        )
    }
}
