import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves fallback dispense manifests through their life cycle and keeps a journal of what it did.
    final class FallbackDispenseManifestCoordinator {
        var store: any FallbackDispenseManifestStore
        var validator: FallbackDispenseManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackDispenseManifestEngine

        init(store: any FallbackDispenseManifestStore, validator: FallbackDispenseManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackDispenseManifestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback dispense manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackDispenseManifestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback dispense manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackDispenseManifestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback dispense manifest \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newFallbackDispenseManifestCoordinator(_ store: any FallbackDispenseManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackDispenseManifestCoordinator {
        return FallbackDispenseManifestCoordinator(
            store: store,
            validator: defaultFallbackDispenseManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackDispenseManifestEngine(flags)
        )
    }
}
