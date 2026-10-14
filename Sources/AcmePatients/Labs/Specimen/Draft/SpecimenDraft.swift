import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen draft is in its life cycle.
    enum SpecimenDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One specimen draft, with what the planners need to act on it.
    final class SpecimenDraft {
        var code: String
        var name: String
        var discount: Double
        var ratio: Double
        var visitMinutes: Int
        var limit: Int
        var externalRef: String
        var ownerID: String
        var contactEmail: String
        var status: SpecimenDraftStatus

        init(code: String, name: String, discount: Double, ratio: Double, visitMinutes: Int, limit: Int, externalRef: String, ownerID: String, contactEmail: String, status: SpecimenDraftStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.ratio = ratio
            self.visitMinutes = visitMinutes
            self.limit = limit
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: SpecimenDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == SpecimenDraftStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SpecimenDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("specimen draft") \(code)"
        }

        func effectiveVolume() -> Double {
            return (Double(visitMinutes) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenDraft {
            return SpecimenDraft(
                code: code,
                name: name,
                discount: discount,
                ratio: ratio,
                visitMinutes: visitMinutes,
                limit: limit,
                externalRef: externalRef,
                ownerID: ownerID,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a specimen draft in status new.
    static func newSpecimenDraft(_ code: String, name: String) -> SpecimenDraft {
        return SpecimenDraft(
            code: code,
            name: name,
            discount: 0.0,
            ratio: 0.0,
            visitMinutes: 0,
            limit: 0,
            externalRef: "",
            ownerID: "",
            contactEmail: "",
            status: SpecimenDraftStatus.new
        )
    }
}
