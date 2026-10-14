import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board review is in its life cycle.
    enum BedBoardReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One bed board review, with what the planners need to act on it.
    final class BedBoardReview {
        var code: String
        var name: String
        var version: Int
        var attempts: Int
        var amount: Double
        var margin: Double
        var approved: Bool
        var diagnosisCode: String
        var createdAt: Int
        var quantity: Int
        var description: String
        var status: BedBoardReviewStatus

        init(code: String, name: String, version: Int, attempts: Int, amount: Double, margin: Double, approved: Bool, diagnosisCode: String, createdAt: Int, quantity: Int, description: String, status: BedBoardReviewStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.attempts = attempts
            self.amount = amount
            self.margin = margin
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
            self.quantity = quantity
            self.description = description
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

        func canMoveTo(_ next: BedBoardReviewStatus) -> Bool {
            switch status {
            case .new:
                return next == BedBoardReviewStatus.queued
            case .queued:
                return next == BedBoardReviewStatus.running || next == BedBoardReviewStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BedBoardReviewStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return (Double(version) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardReview {
            return BedBoardReview(
                code: code,
                name: name,
                version: version,
                attempts: attempts,
                amount: amount,
                margin: margin,
                approved: approved,
                diagnosisCode: diagnosisCode,
                createdAt: createdAt,
                quantity: quantity,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a bed board review in status new.
    static func newBedBoardReview(_ code: String, name: String) -> BedBoardReview {
        return BedBoardReview(
            code: code,
            name: name,
            version: 0,
            attempts: 0,
            amount: 0.0,
            margin: 0.0,
            approved: false,
            diagnosisCode: "",
            createdAt: 0,
            quantity: 0,
            description: "",
            status: BedBoardReviewStatus.new
        )
    }
}
