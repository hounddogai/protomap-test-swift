import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary courier manifest is in its life cycle.
    enum PrimaryCourierManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A primary courier manifest as the courier team keeps it.
    final class PrimaryCourierManifest {
        var code: String
        var title: String
        var specialty: String
        var unit: String
        var ward: String
        var rate: Double
        var refills: Int
        var expiresAt: Int
        var status: PrimaryCourierManifestStatus

        init(code: String, title: String, specialty: String, unit: String, ward: String, rate: Double, refills: Int, expiresAt: Int, status: PrimaryCourierManifestStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.unit = unit
            self.ward = ward
            self.rate = rate
            self.refills = refills
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryCourierManifestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PrimaryCourierManifestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCourierManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary courier manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedVolume() -> Double {
            return (Double(refills) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCourierManifest {
            return PrimaryCourierManifest(
                code: code,
                title: title,
                specialty: specialty,
                unit: unit,
                ward: ward,
                rate: rate,
                refills: refills,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary courier manifest in status planned.
    static func newPrimaryCourierManifest(_ code: String, title: String) -> PrimaryCourierManifest {
        return PrimaryCourierManifest(
            code: code,
            title: title,
            specialty: "",
            unit: "",
            ward: "",
            rate: 0.0,
            refills: 0,
            expiresAt: 0,
            status: PrimaryCourierManifestStatus.planned
        )
    }
}
