import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy reference range manifest is in its life cycle.
    enum LegacyReferenceRangeManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One legacy reference range manifest, with what the planners need to act on it.
    final class LegacyReferenceRangeManifest {
        var code: String
        var name: String
        var floorValue: Double
        var category: String
        var expiresAt: Int
        var revision: Int
        var facility: String
        var segment: String
        var rate: Double
        var approved: Bool
        var status: LegacyReferenceRangeManifestStatus

        init(code: String, name: String, floorValue: Double, category: String, expiresAt: Int, revision: Int, facility: String, segment: String, rate: Double, approved: Bool, status: LegacyReferenceRangeManifestStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.category = category
            self.expiresAt = expiresAt
            self.revision = revision
            self.facility = facility
            self.segment = segment
            self.rate = rate
            self.approved = approved
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

        func canMoveTo(_ next: LegacyReferenceRangeManifestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LegacyReferenceRangeManifestStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: LegacyReferenceRangeManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy reference range manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return ((Double(expiresAt) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyReferenceRangeManifest {
            return LegacyReferenceRangeManifest(
                code: code,
                name: name,
                floorValue: floorValue,
                category: category,
                expiresAt: expiresAt,
                revision: revision,
                facility: facility,
                segment: segment,
                rate: rate,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy reference range manifest in status proposed.
    static func newLegacyReferenceRangeManifest(_ code: String, name: String) -> LegacyReferenceRangeManifest {
        return LegacyReferenceRangeManifest(
            code: code,
            name: name,
            floorValue: 0.0,
            category: "",
            expiresAt: 0,
            revision: 0,
            facility: "",
            segment: "",
            rate: 0.0,
            approved: false,
            status: LegacyReferenceRangeManifestStatus.proposed
        )
    }
}
