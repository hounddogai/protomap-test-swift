import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense exception is in its life cycle.
    enum DispenseExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a dispense exception and its current status.
    final class DispenseException {
        var code: String
        var label: String
        var ownerID: String
        var segment: String
        var retries: Int
        var endsAt: Int
        var title: String
        var version: Int
        var startsAt: Int
        var tags: [String]
        var specialty: String
        var status: DispenseExceptionStatus

        init(code: String, label: String, ownerID: String, segment: String, retries: Int, endsAt: Int, title: String, version: Int, startsAt: Int, tags: [String], specialty: String, status: DispenseExceptionStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.segment = segment
            self.retries = retries
            self.endsAt = endsAt
            self.title = title
            self.version = version
            self.startsAt = startsAt
            self.tags = tags
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseExceptionStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == DispenseExceptionStatus.revoked || next == DispenseExceptionStatus.expired
            case .revoked:
                return next == DispenseExceptionStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("dispense exception") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedValue() -> Double {
            return ((Double(retries) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseException {
            return DispenseException(
                code: code,
                label: label,
                ownerID: ownerID,
                segment: segment,
                retries: retries,
                endsAt: endsAt,
                title: title,
                version: version,
                startsAt: startsAt,
                tags: tags,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a dispense exception in status requested.
    static func newDispenseException(_ code: String, label: String) -> DispenseException {
        return DispenseException(
            code: code,
            label: label,
            ownerID: "",
            segment: "",
            retries: 0,
            endsAt: 0,
            title: "",
            version: 0,
            startsAt: 0,
            tags: [],
            specialty: "",
            status: DispenseExceptionStatus.requested
        )
    }
}
