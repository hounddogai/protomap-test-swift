import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol manifest is in its life cycle.
    enum CareProtocolManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care protocol manifest. Its code is unique within a tenant.
    final class CareProtocolManifest {
        var code: String
        var name: String
        var archived: Bool
        var refills: Int
        var region: String
        var maximum: Double
        var floorValue: Double
        var checksum: String
        var visible: Bool
        var status: CareProtocolManifestStatus

        init(code: String, name: String, archived: Bool, refills: Int, region: String, maximum: Double, floorValue: Double, checksum: String, visible: Bool, status: CareProtocolManifestStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.refills = refills
            self.region = region
            self.maximum = maximum
            self.floorValue = floorValue
            self.checksum = checksum
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolManifestStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolManifestStatus.queued || next == CareProtocolManifestStatus.done
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CareProtocolManifestStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CareProtocolManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedVolume() -> Double {
            return ((floorValue + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolManifest {
            return CareProtocolManifest(
                code: code,
                name: name,
                archived: archived,
                refills: refills,
                region: region,
                maximum: maximum,
                floorValue: floorValue,
                checksum: checksum,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care protocol manifest in status new.
    static func newCareProtocolManifest(_ code: String, name: String) -> CareProtocolManifest {
        return CareProtocolManifest(
            code: code,
            name: name,
            archived: false,
            refills: 0,
            region: "",
            maximum: 0.0,
            floorValue: 0.0,
            checksum: "",
            visible: false,
            status: CareProtocolManifestStatus.new
        )
    }
}
