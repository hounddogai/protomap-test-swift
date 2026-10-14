import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap bundles through their life cycle and keeps a journal of what it did.
    final class CareGapBundleManager {
        var store: any CareGapBundleStore
        var validator: CareGapBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapBundleEngine

        init(store: any CareGapBundleStore, validator: CareGapBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapBundleEngine) {
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
                throw Kit.Failure("care gap bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapBundleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapBundleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap bundle \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newCareGapBundleManager(_ store: any CareGapBundleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareGapBundleManager {
        return CareGapBundleManager(
            store: store,
            validator: defaultCareGapBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapBundleEngine(flags)
        )
    }
}
