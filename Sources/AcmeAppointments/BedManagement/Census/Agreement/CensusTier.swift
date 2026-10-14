import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census tier is in its life cycle.
    enum CensusTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A census tier. Its code is unique within a tenant.
    final class CensusTier {
        var code: String
        var name: String
        var label: String
        var durationMinutes: Int
        var expiresAt: Int
        var allergy: String
        var windowDays: Int
        var pinned: Bool
        var status: CensusTierStatus

        init(code: String, name: String, label: String, durationMinutes: Int, expiresAt: Int, allergy: String, windowDays: Int, pinned: Bool, status: CensusTierStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.windowDays = windowDays
            self.pinned = pinned
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

        func canMoveTo(_ next: CensusTierStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CensusTierStatus.draining || next == CensusTierStatus.stopped
            case .draining:
                return next == CensusTierStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return ((Double(durationMinutes) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> CensusTier {
            return CensusTier(
                code: code,
                name: name,
                label: label,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                allergy: allergy,
                windowDays: windowDays,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a census tier in status idle.
    static func newCensusTier(_ code: String, name: String) -> CensusTier {
        return CensusTier(
            code: code,
            name: name,
            label: "",
            durationMinutes: 0,
            expiresAt: 0,
            allergy: "",
            windowDays: 0,
            pinned: false,
            status: CensusTierStatus.idle
        )
    }
}
