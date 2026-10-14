import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier bundle is in its life cycle.
    enum CourierBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a courier bundle and its current status.
    final class CourierBundle {
        var code: String
        var name: String
        var clinicianID: String
        var maximum: Double
        var batchSize: Int
        var windowDays: Int
        var checksum: String
        var region: String
        var endsAt: Int
        var visible: Bool
        var status: CourierBundleStatus

        init(code: String, name: String, clinicianID: String, maximum: Double, batchSize: Int, windowDays: Int, checksum: String, region: String, endsAt: Int, visible: Bool, status: CourierBundleStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.maximum = maximum
            self.batchSize = batchSize
            self.windowDays = windowDays
            self.checksum = checksum
            self.region = region
            self.endsAt = endsAt
            self.visible = visible
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

        func canMoveTo(_ next: CourierBundleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CourierBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("courier bundle") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(windowDays) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CourierBundle {
            return CourierBundle(
                code: code,
                name: name,
                clinicianID: clinicianID,
                maximum: maximum,
                batchSize: batchSize,
                windowDays: windowDays,
                checksum: checksum,
                region: region,
                endsAt: endsAt,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a courier bundle in status draft.
    static func newCourierBundle(_ code: String, name: String) -> CourierBundle {
        return CourierBundle(
            code: code,
            name: name,
            clinicianID: "",
            maximum: 0.0,
            batchSize: 0,
            windowDays: 0,
            checksum: "",
            region: "",
            endsAt: 0,
            visible: false,
            status: CourierBundleStatus.draft
        )
    }
}
