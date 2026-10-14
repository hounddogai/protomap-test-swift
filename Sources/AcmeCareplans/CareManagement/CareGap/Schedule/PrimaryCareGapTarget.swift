import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary care gap target is in its life cycle.
    enum PrimaryCareGapTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a primary care gap target and its current status.
    final class PrimaryCareGapTarget {
        var code: String
        var name: String
        var diagnosisCode: String
        var locale: String
        var createdAt: Int
        var status: PrimaryCareGapTargetStatus

        init(code: String, name: String, diagnosisCode: String, locale: String, createdAt: Int, status: PrimaryCareGapTargetStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.locale = locale
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryCareGapTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryCareGapTargetStatus.reopened || next == PrimaryCareGapTargetStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryCareGapTargetStatus.reopened
            case .reopened:
                return next == PrimaryCareGapTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCareGapTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary care gap target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> PrimaryCareGapTarget {
            return PrimaryCareGapTarget(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                locale: locale,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a primary care gap target in status open.
    static func newPrimaryCareGapTarget(_ code: String, name: String) -> PrimaryCareGapTarget {
        return PrimaryCareGapTarget(
            code: code,
            name: name,
            diagnosisCode: "",
            locale: "",
            createdAt: 0,
            status: PrimaryCareGapTargetStatus.`open`
        )
    }
}
