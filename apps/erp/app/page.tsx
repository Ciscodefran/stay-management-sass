export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-24">
      <main className="flex flex-col items-center gap-8">
        <h1 className="text-4xl font-bold text-primary">ERP App</h1>
        <p className="text-lg text-muted-foreground">
          Stay Management ERP Application
        </p>
        <div className="flex gap-4">
          <div className="rounded-lg bg-brand-500 px-4 py-2 text-white">
            Brand Color
          </div>
          <div className="rounded-lg bg-primary px-4 py-2 text-primary-foreground">
            Primary Color
          </div>
        </div>
      </main>
    </div>
  );
}
