import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol window is in its life cycle.
    enum CareProtocolWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol window. Its code is unique within a tenant.
    final class CareProtocolWindow {
        var code: String
        var title: String
        var ceiling: Double
        var version: Int
        var cost: Double
        var source: String
        var visitMinutes: Int
        var ownerID: String
        var status: CareProtocolWindowStatus

        init(code: String, title: String, ceiling: Double, version: Int, cost: Double, source: String, visitMinutes: Int, ownerID: String, status: CareProtocolWindowStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.version = version
            self.cost = cost
            self.source = source
            self.visitMinutes = visitMinutes
            self.ownerID = ownerID
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

        func canMoveTo(_ next: CareProtocolWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == CareProtocolWindowStatus.ready || next == CareProtocolWindowStatus.draining
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CareProtocolWindowStatus.draining
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

        func moveTo(_ next: CareProtocolWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedVolume() -> Double {
            return (Double(visitMinutes) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolWindow {
            return CareProtocolWindow(
                code: code,
                title: title,
                ceiling: ceiling,
                version: version,
                cost: cost,
                source: source,
                visitMinutes: visitMinutes,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care protocol window in status idle.
    static func newCareProtocolWindow(_ code: String, title: String) -> CareProtocolWindow {
        return CareProtocolWindow(
            code: code,
            title: title,
            ceiling: 0.0,
            version: 0,
            cost: 0.0,
            source: "",
            visitMinutes: 0,
            ownerID: "",
            status: CareProtocolWindowStatus.idle
        )
    }
}
