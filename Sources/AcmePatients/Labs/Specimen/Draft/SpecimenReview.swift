import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen review is in its life cycle.
    enum SpecimenReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One specimen review, with what the planners need to act on it.
    final class SpecimenReview {
        var code: String
        var label: String
        var capacity: Int
        var region: String
        var description: String
        var batchSize: Int
        var approved: Bool
        var allergy: String
        var copay: Double
        var checksum: String
        var quantity: Int
        var status: SpecimenReviewStatus

        init(code: String, label: String, capacity: Int, region: String, description: String, batchSize: Int, approved: Bool, allergy: String, copay: Double, checksum: String, quantity: Int, status: SpecimenReviewStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.region = region
            self.description = description
            self.batchSize = batchSize
            self.approved = approved
            self.allergy = allergy
            self.copay = copay
            self.checksum = checksum
            self.quantity = quantity
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

        func canMoveTo(_ next: SpecimenReviewStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == SpecimenReviewStatus.draining
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

        func moveTo(_ next: SpecimenReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return (copay * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenReview {
            return SpecimenReview(
                code: code,
                label: label,
                capacity: capacity,
                region: region,
                description: description,
                batchSize: batchSize,
                approved: approved,
                allergy: allergy,
                copay: copay,
                checksum: checksum,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a specimen review in status idle.
    static func newSpecimenReview(_ code: String, label: String) -> SpecimenReview {
        return SpecimenReview(
            code: code,
            label: label,
            capacity: 0,
            region: "",
            description: "",
            batchSize: 0,
            approved: false,
            allergy: "",
            copay: 0.0,
            checksum: "",
            quantity: 0,
            status: SpecimenReviewStatus.idle
        )
    }
}
