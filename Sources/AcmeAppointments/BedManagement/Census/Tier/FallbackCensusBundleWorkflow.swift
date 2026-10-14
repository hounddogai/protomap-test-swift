import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves fallback census bundles through their life cycle and keeps a journal of what it did.
    final class FallbackCensusBundleDesk {
        var store: any FallbackCensusBundleStore
        var validator: FallbackCensusBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackCensusBundleEngine

        init(store: any FallbackCensusBundleStore, validator: FallbackCensusBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackCensusBundleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback census bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCensusBundleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback census bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCensusBundleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback census bundle \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newFallbackCensusBundleDesk(_ store: any FallbackCensusBundleStore, clock: any Kit.Clocks.Clock) -> FallbackCensusBundleDesk {
        return FallbackCensusBundleDesk(
            store: store,
            validator: defaultFallbackCensusBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackCensusBundleEngine()
        )
    }
}
