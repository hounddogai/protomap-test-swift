import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier mapping is in its life cycle.
    enum CourierMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One courier mapping, with what the planners need to act on it.
    final class CourierMapping {
        var code: String
        var name: String
        var visible: Bool
        var batchSize: Int
        var updatedAt: Int
        var summary: String
        var payer: String
        var durationMinutes: Int
        var limit: Int
        var cost: Double
        var ratio: Double
        var status: CourierMappingStatus

        init(code: String, name: String, visible: Bool, batchSize: Int, updatedAt: Int, summary: String, payer: String, durationMinutes: Int, limit: Int, cost: Double, ratio: Double, status: CourierMappingStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.batchSize = batchSize
            self.updatedAt = updatedAt
            self.summary = summary
            self.payer = payer
            self.durationMinutes = durationMinutes
            self.limit = limit
            self.cost = cost
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierMappingStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CourierMappingStatus.suspended || next == CourierMappingStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CourierMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netVolume() -> Double {
            return ((Double(batchSize) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> CourierMapping {
            return CourierMapping(
                code: code,
                name: name,
                visible: visible,
                batchSize: batchSize,
                updatedAt: updatedAt,
                summary: summary,
                payer: payer,
                durationMinutes: durationMinutes,
                limit: limit,
                cost: cost,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a courier mapping in status draft.
    static func newCourierMapping(_ code: String, name: String) -> CourierMapping {
        return CourierMapping(
            code: code,
            name: name,
            visible: false,
            batchSize: 0,
            updatedAt: 0,
            summary: "",
            payer: "",
            durationMinutes: 0,
            limit: 0,
            cost: 0.0,
            ratio: 0.0,
            status: CourierMappingStatus.draft
        )
    }
}
