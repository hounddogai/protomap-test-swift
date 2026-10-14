import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession digest is in its life cycle.
    enum AccessionDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One accession digest, with what the planners need to act on it.
    final class AccessionDigest {
        var code: String
        var title: String
        var archived: Bool
        var quantity: Int
        var visible: Bool
        var minimum: Double
        var startsAt: Int
        var diagnosisCode: String
        var priority: Int
        var acuity: Int
        var visitMinutes: Int
        var status: AccessionDigestStatus

        init(code: String, title: String, archived: Bool, quantity: Int, visible: Bool, minimum: Double, startsAt: Int, diagnosisCode: String, priority: Int, acuity: Int, visitMinutes: Int, status: AccessionDigestStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.quantity = quantity
            self.visible = visible
            self.minimum = minimum
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.acuity = acuity
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: AccessionDigestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AccessionDigestStatus.done || next == AccessionDigestStatus.failed
            case .done:
                return next == AccessionDigestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("accession digest") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(priority) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionDigest {
            return AccessionDigest(
                code: code,
                title: title,
                archived: archived,
                quantity: quantity,
                visible: visible,
                minimum: minimum,
                startsAt: startsAt,
                diagnosisCode: diagnosisCode,
                priority: priority,
                acuity: acuity,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession digest in status new.
    static func newAccessionDigest(_ code: String, title: String) -> AccessionDigest {
        return AccessionDigest(
            code: code,
            title: title,
            archived: false,
            quantity: 0,
            visible: false,
            minimum: 0.0,
            startsAt: 0,
            diagnosisCode: "",
            priority: 0,
            acuity: 0,
            visitMinutes: 0,
            status: AccessionDigestStatus.new
        )
    }
}
