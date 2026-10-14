import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense manifests through their life cycle and keeps a journal of what it did.
    final class DispenseManifestCoordinator {
        var store: any DispenseManifestStore
        var validator: DispenseManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DispenseManifestEngine

        init(store: any DispenseManifestStore, validator: DispenseManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DispenseManifestEngine) {
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
                throw Kit.Failure("dispense manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseManifestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseManifestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense manifest \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newDispenseManifestCoordinator(_ store: any DispenseManifestStore, clock: any Kit.Clocks.Clock) -> DispenseManifestCoordinator {
        return DispenseManifestCoordinator(
            store: store,
            validator: defaultDispenseManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultDispenseManifestEngine()
        )
    }
}
