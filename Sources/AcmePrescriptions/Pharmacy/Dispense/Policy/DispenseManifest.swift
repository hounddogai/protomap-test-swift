import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense manifest is in its life cycle.
    enum DispenseManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A dispense manifest. Its code is unique within a tenant.
    final class DispenseManifest {
        var code: String
        var name: String
        var patientRef: String
        var region: String
        var visible: Bool
        var score: Double
        var threshold: Double
        var facility: String
        var specialty: String
        var version: Int
        var locale: String
        var status: DispenseManifestStatus

        init(code: String, name: String, patientRef: String, region: String, visible: Bool, score: Double, threshold: Double, facility: String, specialty: String, version: Int, locale: String, status: DispenseManifestStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.region = region
            self.visible = visible
            self.score = score
            self.threshold = threshold
            self.facility = facility
            self.specialty = specialty
            self.version = version
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == DispenseManifestStatus.validated || next == DispenseManifestStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DispenseManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((threshold + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseManifest {
            return DispenseManifest(
                code: code,
                name: name,
                patientRef: patientRef,
                region: region,
                visible: visible,
                score: score,
                threshold: threshold,
                facility: facility,
                specialty: specialty,
                version: version,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a dispense manifest in status created.
    static func newDispenseManifest(_ code: String, name: String) -> DispenseManifest {
        return DispenseManifest(
            code: code,
            name: name,
            patientRef: "",
            region: "",
            visible: false,
            score: 0.0,
            threshold: 0.0,
            facility: "",
            specialty: "",
            version: 0,
            locale: "",
            status: DispenseManifestStatus.created
        )
    }
}
