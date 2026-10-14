import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction target is in its life cycle.
    enum InteractionTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a interaction target and its current status.
    final class InteractionTarget {
        var code: String
        var name: String
        var bed: String
        var payer: String
        var floorValue: Double
        var archived: Bool
        var refills: Int
        var status: InteractionTargetStatus

        init(code: String, name: String, bed: String, payer: String, floorValue: Double, archived: Bool, refills: Int, status: InteractionTargetStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.payer = payer
            self.floorValue = floorValue
            self.archived = archived
            self.refills = refills
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

        func canMoveTo(_ next: InteractionTargetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
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
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: InteractionTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return ((floorValue - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionTarget {
            return InteractionTarget(
                code: code,
                name: name,
                bed: bed,
                payer: payer,
                floorValue: floorValue,
                archived: archived,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a interaction target in status idle.
    static func newInteractionTarget(_ code: String, name: String) -> InteractionTarget {
        return InteractionTarget(
            code: code,
            name: name,
            bed: "",
            payer: "",
            floorValue: 0.0,
            archived: false,
            refills: 0,
            status: InteractionTargetStatus.idle
        )
    }
}
