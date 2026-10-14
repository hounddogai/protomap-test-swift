import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness digests through their life cycle and keeps a journal of what it did.
    final class WitnessDigestCoordinator {
        var store: any WitnessDigestStore
        var validator: WitnessDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WitnessDigestEngine

        init(store: any WitnessDigestStore, validator: WitnessDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WitnessDigestEngine) {
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
                throw Kit.Failure("witness digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessDigestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessDigestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness digest \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newWitnessDigestCoordinator(_ store: any WitnessDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WitnessDigestCoordinator {
        return WitnessDigestCoordinator(
            store: store,
            validator: defaultWitnessDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultWitnessDigestEngine(flags)
        )
    }
}
