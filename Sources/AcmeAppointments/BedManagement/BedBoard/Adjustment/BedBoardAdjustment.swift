import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board adjustment is in its life cycle.
    enum BedBoardAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a bed board adjustment and its current status.
    final class BedBoardAdjustment {
        var code: String
        var label: String
        var attempts: Int
        var clinicianID: String
        var expiresAt: Int
        var capacity: Int
        var country: String
        var ward: String
        var payer: String
        var category: String
        var rate: Double
        var status: BedBoardAdjustmentStatus

        init(code: String, label: String, attempts: Int, clinicianID: String, expiresAt: Int, capacity: Int, country: String, ward: String, payer: String, category: String, rate: Double, status: BedBoardAdjustmentStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.clinicianID = clinicianID
            self.expiresAt = expiresAt
            self.capacity = capacity
            self.country = country
            self.ward = ward
            self.payer = payer
            self.category = category
            self.rate = rate
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

        func canMoveTo(_ next: BedBoardAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BedBoardAdjustmentStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: BedBoardAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("bed board adjustment") \(code)"
        }

        func projectedLoad() -> Double {
            return ((rate + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardAdjustment {
            return BedBoardAdjustment(
                code: code,
                label: label,
                attempts: attempts,
                clinicianID: clinicianID,
                expiresAt: expiresAt,
                capacity: capacity,
                country: country,
                ward: ward,
                payer: payer,
                category: category,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a bed board adjustment in status open.
    static func newBedBoardAdjustment(_ code: String, label: String) -> BedBoardAdjustment {
        return BedBoardAdjustment(
            code: code,
            label: label,
            attempts: 0,
            clinicianID: "",
            expiresAt: 0,
            capacity: 0,
            country: "",
            ward: "",
            payer: "",
            category: "",
            rate: 0.0,
            status: BedBoardAdjustmentStatus.`open`
        )
    }
}
