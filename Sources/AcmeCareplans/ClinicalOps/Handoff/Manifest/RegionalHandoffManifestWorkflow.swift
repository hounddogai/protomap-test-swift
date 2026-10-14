import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves regional handoff manifests through their life cycle and keeps a journal of what it did.
    final class RegionalHandoffManifestService {
        var store: any RegionalHandoffManifestStore
        var validator: RegionalHandoffManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalHandoffManifestEngine

        init(store: any RegionalHandoffManifestStore, validator: RegionalHandoffManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalHandoffManifestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional handoff manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalHandoffManifestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional handoff manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalHandoffManifestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional handoff manifest \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newRegionalHandoffManifestService(_ store: any RegionalHandoffManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalHandoffManifestService {
        return RegionalHandoffManifestService(
            store: store,
            validator: defaultRegionalHandoffManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalHandoffManifestEngine(flags)
        )
    }
}
