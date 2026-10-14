import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read manifest is in its life cycle.
    enum ReadManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a read manifest and its current status.
    final class ReadManifest {
        var code: String
        var name: String
        var description: String
        var sequence: Int
        var quantity: Int
        var graceDays: Int
        var floorValue: Double
        var margin: Double
        var segment: String
        var status: ReadManifestStatus

        init(code: String, name: String, description: String, sequence: Int, quantity: Int, graceDays: Int, floorValue: Double, margin: Double, segment: String, status: ReadManifestStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.sequence = sequence
            self.quantity = quantity
            self.graceDays = graceDays
            self.floorValue = floorValue
            self.margin = margin
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReadManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ReadManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedVolume() -> Double {
            return (floorValue * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> ReadManifest {
            return ReadManifest(
                code: code,
                name: name,
                description: description,
                sequence: sequence,
                quantity: quantity,
                graceDays: graceDays,
                floorValue: floorValue,
                margin: margin,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a read manifest in status proposed.
    static func newReadManifest(_ code: String, name: String) -> ReadManifest {
        return ReadManifest(
            code: code,
            name: name,
            description: "",
            sequence: 0,
            quantity: 0,
            graceDays: 0,
            floorValue: 0.0,
            margin: 0.0,
            segment: "",
            status: ReadManifestStatus.proposed
        )
    }
}
